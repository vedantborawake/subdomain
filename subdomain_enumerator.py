import requests
import dns.resolver
import os

def fetch_subdomains(domain, wordlist_file, output_file):
    subdomains = []
    
    # Read wordlist
    with open(wordlist_file, 'r') as file:
        words = [line.strip() for line in file]
    
    print("\n[+] Finding subdomains for:", domain)
    
    for sub in words:
        subdomain = f"{sub}.{domain}"
        try:
            dns.resolver.resolve(subdomain, 'A')  # DNS resolution
            print(f"[✔] Found: {subdomain}")
            subdomains.append(subdomain)
        except (dns.resolver.NXDOMAIN, dns.resolver.NoAnswer, dns.resolver.Timeout):
            pass
    
    # Save results to file
    with open(output_file, 'w') as f:
        for sub in subdomains:
            f.write(sub + '\n')
    
    print(f"\n[+] Results saved to {output_file}")

# Terminal Interface
def main():
    print("\n==== Simple Subdomain Finder ====")
    domain = input("Enter target domain: ")
    wordlist_file = input("Enter path to wordlist file: ")
    output_file = input("Enter output filename: ")
    fetch_subdomains(domain, wordlist_file, output_file)
    print("\n[+] Subdomain Enumeration Completed!")

if __name__ == "__main__":
    main()
