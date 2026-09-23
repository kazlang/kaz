use std::hint::black_box;
use std::time::Instant;

fn fib(n: i64) -> i64 {
    if n <= 1 {
        return n;
    }
    fib(n - 1) + fib(n - 2)
}

fn bench_n(target_n: i64, runs: usize) {
    // Warm-up de 5 iterações para estabilizar cache L1/L2 de instruções da CPU
    for _ in 0..5 {
        black_box(fib(black_box(target_n)));
    }

    let mut times: Vec<u128> = Vec::with_capacity(runs);
    let mut last_res = 0;

    for _ in 0..runs {
        let n = black_box(target_n);
        let t0 = Instant::now();
        last_res = black_box(fib(black_box(n)));
        let elapsed = t0.elapsed().as_micros();
        times.push(elapsed);
    }

    let sum: u128 = times.iter().sum();
    let mean_us = sum / (runs as u128);
    let min_us = *times.iter().min().unwrap();
    let max_us = *times.iter().max().unwrap();
    times.sort();
    let median_us = if runs % 2 == 1 {
        times[runs / 2]
    } else {
        (times[runs / 2 - 1] + times[runs / 2]) / 2
    };

    println!("fib({}) = {} | Media: {} us | Mediana: {} us | Min: {} us | Max: {} us ({} repeticoes)",
        target_n, last_res, mean_us, median_us, min_us, max_us, runs);
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() > 1 {
        let n: i64 = args[1].parse().unwrap_or(26);
        let runs = if n >= 32 { 15 } else { 50 };
        println!("==================================================================");
        println!("   RUST NATIVO (LLVM -O3) - EXECUCAO DINAMICA VIA ARGV");
        println!("   (Argumento n = {} recebido via linha de comando)", n);
        println!("==================================================================");
        bench_n(n, runs);
        return;
    }

    println!("==================================================================");
    println!("   RUST NATIVO (LLVM -O3) - BATERIA COMPLETA DE BENCHMARKS");
    println!("   (std::hint::black_box impedindo qualquer Constant Folding)");
    println!("==================================================================");

    bench_n(20, 50);
    bench_n(24, 50);
    bench_n(26, 50);
    bench_n(28, 50);
    bench_n(30, 30);
    bench_n(32, 20);
    bench_n(34, 15);
}
