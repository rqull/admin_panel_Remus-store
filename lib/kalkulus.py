import time

# Parameter PID
Kp = 0.6  # Gain Proportional
Ki = 0.1  # Gain Integral
Kd = 0.05 # Gain Derivative

# Nilai target (setpoint)
target_speed = 60.0  # Kecepatan target (km/jam)

# Variabel awal
current_speed = 0.0  # Kecepatan awal mobil
previous_error = 0.0 # Error sebelumnya
integral = 0.0       # Akumulasi integral

# Fungsi simulasi sistem (dinamika kecepatan mobil)
def car_simulation(gas_input, current_speed):
    """
    Fungsi sederhana yang mensimulasikan kecepatan mobil.
    Semakin besar gas_input, semakin cepat kecepatan bertambah.
    """
    # Simulasi sederhana: kecepatan berubah sebanding dengan gas_input
    acceleration = gas_input * 0.1  # Faktor akselerasi
    current_speed += acceleration
    # Tambahkan hambatan
    current_speed -= 0.02  # Hambatan kecil (gesekan)
    return current_speed

# Loop kontrol PID
for i in range(1, 101):  # Loop 100 iterasi
    # Hitung error
    error = target_speed - current_speed

    # Komponen Proportional
    P = Kp * error

    # Komponen Integral
    integral += error
    I = Ki * integral

    # Komponen Derivative
    derivative = error - previous_error
    D = Kd * derivative

    # Total kontrol PID
    control_signal = P + I + D

    # Simulasi efek kontrol (gas_input) ke mobil
    current_speed = car_simulation(control_signal, current_speed)

    # Update error sebelumnya
    previous_error = error

    # Cetak hasil setiap iterasi
    print(f"Iterasi {i}: Kecepatan = {current_speed:.2f} km/jam, Error = {error:.2f}")

    # Tunggu sebentar agar simulasi lebih realistis
    time.sleep(0.1)

print("Simulasi selesai.")
