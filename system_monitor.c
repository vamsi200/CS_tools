#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

#define MAX_TEMPERATURE 80.00
long no_of_online_process;
float cpu_temp;
int max_scaling_freq, min_scaling_freq;
char model_name;

int get_cpu_temp(void){
	FILE *open_file = fopen("/sys/class/thermal/thermal_zone0/temp", "r");
	if (open_file == NULL){
		perror("Couldn't Read Cpu Temperature");
		return -1;
	} else {
		fscanf(open_file, "%f", &cpu_temp);
		fclose(open_file);
		return cpu_temp / 1000.0;
	}
}

int throttle_and_get_max_frequency(void) {
    int max_cpu = sysconf(_SC_NPROCESSORS_ONLN);  
    FILE *fp_max;
    char max_cpu_freq_filepath[256];

    for (int cpu = 0; cpu < max_cpu; cpu++) {
        snprintf(max_cpu_freq_filepath, sizeof(max_cpu_freq_filepath), "/sys/devices/system/cpu/cpu%d/cpufreq/scaling_max_freq", cpu);

        fp_max = fopen(max_cpu_freq_filepath, "r");
        if (fp_max == NULL) {
            perror("Couldn't Read CPU Frequency");
            continue;
        }

        if (fscanf(fp_max, "%d", &max_scaling_freq) != 1) {
            perror("Error reading max scaling frequency");
            fclose(fp_max);
            continue;
        }
        
        fclose(fp_max);  

        int throttle_freq = max_scaling_freq / 2;
        printf("CPU%d: Max Frequency = %d Hz, Throttled Frequency = %d Hz\n", cpu, max_scaling_freq, throttle_freq);

        
        snprintf(max_cpu_freq_filepath, sizeof(max_cpu_freq_filepath), "/sys/devices/system/cpu/cpu%d/cpufreq/scaling_max_freq", cpu);
        FILE *fp_set = fopen(max_cpu_freq_filepath, "w");
        if (fp_set == NULL) {
            perror("Couldn't Set Throttled Frequency");
            continue;
        }
        fprintf(fp_set, "%d", throttle_freq);  
	fclose(fp_set);
        
    }

    return 0;
}

int main() {
    printf("Throttle and Get Max Frequency:\n");
    throttle_and_get_max_frequency();

    return 0;
}

