use std::hint::black_box;
use std::time::Instant;

fn fib(n: i64) -> i64 {
    if n <= 1 {
        return n;
    }
    fib(n - 1) + fib(n - 2)
}

struct Ponto3D {
    x: f64,
    y: f64,
    z: f64,
}

fn main() {
    println!("╔══════════════════════════════════════════════════════════════════════╗");
    println!("║               RUST NATIVO (LLVM -O3) - BENCHMARK SUITE               ║");
    println!("╚══════════════════════════════════════════════════════════════════════╝\n");

    // 1. Fibonacci 26
    let t0 = Instant::now();
    let res_fib = black_box(fib(black_box(26)));
    let t_fib = t0.elapsed();
    println!("→ Teste 1: Recursão Profunda - Fibonacci(26)");
    println!("  • Resultado: fib(26) = {}", res_fib);
    println!(
        "  • Tempo decorrido: {:.3} ms ({:.1} us)\n",
        t_fib.as_secs_f64() * 1000.0,
        t_fib.as_micros() as f64
    );

    // 2. Loop 50.000 iterações
    let t0 = Instant::now();
    let mut acumulador: f64 = 0.0;
    for i in 1..=50000 {
        let i_f = black_box(i as f64);
        acumulador += (i_f * 1.5) - (i_f / 2.0);
    }
    let t_loop = t0.elapsed();
    println!("→ Teste 2: Loop Aritmético (50.000 iterações)");
    println!("  • Acumulador final: {}", acumulador);
    println!(
        "  • Tempo decorrido:  {:.3} ms ({:.1} us)\n",
        t_loop.as_secs_f64() * 1000.0,
        t_loop.as_micros() as f64
    );

    // 3. Structs 10.000 instâncias
    let t0 = Instant::now();
    let mut soma_distancias: f64 = 0.0;
    for j in 1..=10000 {
        let j_f = black_box(j as f64);
        let p = black_box(Ponto3D {
            x: j_f * 1.0,
            y: j_f * 2.0,
            z: j_f * 3.0,
        });
        soma_distancias += (p.x * p.x + p.y * p.y + p.z * p.z).sqrt();
    }
    let t_struct = t0.elapsed();
    println!("→ Teste 3: Criação e Manipulação de Structs (10.000 instâncias)");
    println!("  • Soma das distâncias: {}", soma_distancias);
    println!(
        "  • Tempo decorrido:     {:.3} ms ({:.1} us)\n",
        t_struct.as_secs_f64() * 1000.0,
        t_struct.as_micros() as f64
    );

    let t_total = t_fib + t_loop + t_struct;
    println!("========================================================================");
    println!("  RESULTADOS CONSOLIDADOS - RUST NATIVO (-O3) 🦀");
    println!(
        "  • Recursão de CallFrames (Fib 26): {:.3} ms",
        t_fib.as_secs_f64() * 1000.0
    );
    println!(
        "  • Dispatch de Loop (50k ops):      {:.3} ms",
        t_loop.as_secs_f64() * 1000.0
    );
    println!(
        "  • Heap & Structs (10k instâncias): {:.3} ms",
        t_struct.as_secs_f64() * 1000.0
    );
    println!(
        "  • TEMPO TOTAL DA SUÍTE:            {:.3} ms",
        t_total.as_secs_f64() * 1000.0
    );
    println!("========================================================================\n");
}
