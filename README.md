# DACI-FPGA-capstone-wvutech
This code will be utilized in the design of an FPGA-based Data Acquisition Unit

During the Fall 2024 and Spring 2025 semesters, this project aimed to develop a low-cost, high-performance data acquisition (DAQ) system for power lab applications, leveraging the flexibility and efficiency of Field-Programmable Gate Arrays (FPGAs). The system is designed to meet the specific needs of educational environments and laboratory settings, where budget constraints often limit access to advanced DAQ technologies. By combining FPGA hardware with a user-friendly interface developed in C++, the project aims to create a versatile solution that balances cost-effectiveness with functionality.

The project is structured around two primary components: the hardware and the software. The hardware component focuses on the design and implementation of an FPGA-based system that is capable of handling data collection and processing with low latency. The FPGA’s processing capabilities allow for real-time signal acquisition, processing, and data output, ensuring the system is capable of supporting a wide range of educational experiments and demonstrations.

The software component seeks to implement a custom user interface developed in C++ to provide easy interaction with the system. This interface enables users to configure the DAQ system, visualize acquired data, and perform analysis tasks efficiently. The intuitive design aims to simplify the user experience for both instructors and students, ensuring that the system is accessible even to those with limited technical expertise.

The interdisciplinary nature of this project draws from electrical engineering, computer engineering, and software development. By bridging the gap between traditional, expensive data acquisition systems and modern, affordable alternatives, the team aims to provide a flexible and scalable solution for educational institutions and laboratories. The system’s modular design allows for future expansion, ensuring that it can evolve alongside emerging technological needs.

The proposed data acquisition system to be developed has a budgeted cost of 400 dollars with the addition of a donated De-10 LITE FPGA board. This budget includes all required printed circuit boards, sensors for measurement, analog to digital converters, and miscellaneous connected breakout circuitry required elements. This cost will greatly decrease the overall cost of the systems compared to the current LabVolt system which has a base cost of 1500 dollars with the additional cost for licensing. Development of the project remained within this allotted budget.

This specific GitHub Repository will be utilized in the development of VHDL to be utilized with the DE-10 Lite FPGA Development Kit. Currently, the FPGA_Prototype section contains the VHDL code that the DE-10 Lite FPGA is programmed with to effectively capture data and send it via a UART chip to the C++ developed software to display the captured data. The Verilog_FPGAtoPeriph section will contain similar code that may be used if the project might want to be completed in the Verilog language.

![Screenshot_DE10_Lite_FPGA](https://github.com/user-attachments/assets/ea1ff969-d5d5-4df2-aae3-5566f7dc1034)

I have also included a hyperlink to a testbench playground that will allow a view of the waveforms with the testbench I created to test the full functionality of the VHDL code for the purpose of this capstone project: https://www.edaplayground.com/x/mWM3.
