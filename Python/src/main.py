from numpy import loadtxt
from tolsolvty import tolsolvty


def main():
    path_folder = '../example'

    infA = loadtxt(path_folder + '/infA.txt')
    supA = loadtxt(path_folder + '/supA.txt')

    infb = loadtxt(path_folder + '/infb.txt', ndmin=2)
    supb = loadtxt(path_folder + '/supb.txt', ndmin=2)

    [tolmax, argmax, envs, ccode] = tolsolvty(infA, supA, infb, supb)
    print('tolmax = ', tolmax)
    print('argmax = ', argmax)
    print('envs = ', envs)
    print('ccode = ', ccode)


if __name__ == "__main__":
    main()
