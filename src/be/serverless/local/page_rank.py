import time
import pandas as pd
import networkx as nx
from networkx import NetworkXError
import json
import matplotlib.pyplot as plt


def ingest(filename):
    MG = nx.DiGraph()
    f = open(filename)
    data = json.load(f)
    for page, data in data["pages"].items():
        for link in data["backlinks"]:
            MG.add_edge(page, link, weight=1)
    nx.draw(MG, with_labels=True)
    plt.show(block=True)
    undirected_MG = MG.to_undirected()
    print([c for c in sorted(nx.connected_components(undirected_MG), key=len, reverse=True)])

    return MG


def pagerank(G, alpha=0.85, personalization=None,
             max_iter=100, tol=1.0e-6, nstart=None, weight='weight',
             dangling=None):
    """Return the PageRank of the nodes in the graph.

    PageRank computes a ranking of the nodes in the graph G based on
    the structure of the incoming links. It was originally designed as
    an algorithm to rank web pages.

    Parameters

    G: graph
    A NetworkX graph. Undirected graphs will be transformed into a directed graph with two directed
    edges for each undirected edge.

    alpha: float, optional
    Damping parameter for PageRank, with a default value of 0.85.

    personalization: dict, optional
    The "personalization vector" represented as a dictionary, with a key for each graph node and a
    non-zero personalization value for each node. By default, a uniform distribution is used.

    max_iter: integer, optional
    The maximum number of iterations in the power method eigenvalue solver.

    tol: float, optional
    The error tolerance used to assess convergence in the power method solver.

    nstart: dictionary, optional
    The initial PageRank values for each node.

    weight: key, optional
    The edge data key to be used as the weight. If set to None, weights are assumed to be 1.

    dangling: dict, optional
    The outedges to be assigned to any "dangling" nodes, i.e., nodes without any outedges.
    The dictionary key indicates the node to which the outedge points, and the dictionary value
    represents the weight of that outedge. By default, dangling nodes receive outedges based on the
    personalization vector (uniform if not specified).

    Returns
    -------
    pagerank : dictionary
    A dictionary of nodes with PageRank as value
    """
    if len(G) == 0:
        return {}

    D = G if G.is_directed() else G.to_directed()
    A = nx.adjacency_matrix(D)

    print(A.todense())
    # Create a copy in (right) stochastic form
    W = nx.stochastic_graph(D, weight=weight)
    A = nx.adjacency_matrix(W)

    print(A.todense())
    N = W.number_of_nodes()

    # Choose fixed starting vector if not given
    if nstart is None:
        x = dict.fromkeys(W, 1.0 / N)
    else:
        # Normalized nstart vector
        s = float(sum(nstart.values()))
        x = {k: v / s for k, v in nstart.items()}

    if personalization is None:

        # Assign uniform personalization vector if not given
        p = dict.fromkeys(W, 1.0 / N)
    else:
        missing = set(G) - set(personalization)
        if missing:
            raise NetworkXError('Personalization dictionary '
                                'must have a value for every node. '
                                'Missing nodes %s' % missing)
        s = float(sum(personalization.values()))
        p = dict((k, v / s) for k, v in personalization.items())

    print(p)

    if dangling is None:
        # Use personalization vector if dangling vector not specified
        dangling_weights = p
    else:
        missing = set(G) - set(dangling)
        if missing:
            raise NetworkXError('Dangling node dictionary '
                                'must have a value for every node. '
                                'Missing nodes %s' % missing)
        s = float(sum(dangling.values()))
        dangling_weights = dict((k, v / s) for k, v in dangling.items())
    dangling_nodes = [n for n in W if W.out_degree(n, weight=weight) == 0.0]


    # power iteration: make up to max_iter iterations
    iter_list = []
    iter_list.append(p)
    for _ in range(max_iter):
        xlast = x
        x = dict.fromkeys(xlast.keys(), 0)
        danglesum = alpha * sum(xlast[n] for n in dangling_nodes)
        for n in x:
            # this matrix multiply looks odd because it is
            # doing a left multiply x^T=xlast^T*W
            for nbr in W[n]:
                x[nbr] += alpha * xlast[n] * W[n][nbr][weight]
            x[n] += danglesum * dangling_weights[n] + (1.0 - alpha) * p[n]

        # check convergence, l1 norm
        err = sum(abs(x[n] - xlast[n]) for n in x)
        print(x)
        iter_list.append(x)
        if err < N * tol:
            df = pd.DataFrame(iter_list)
            for column in df.columns:
                plt.plot(df.index, df[column], marker='o', label=column)
            plt.xlabel('Iteration Number')
            plt.ylabel('Ranking')
            plt.title('Behavior of Values Over Iterations')
            plt.xticks(df.index)  # Set x-axis ticks to match the index
            plt.legend(loc='upper right')
            plt.show()
            return x

    raise NetworkXError('pagerank: power iteration failed to converge '
                        'in %d iterations.' % max_iter)


Graph = ingest("test_cases/test.json")
print(pagerank(Graph))
print(nx.pagerank(Graph))