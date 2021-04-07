import pathlib
import os
import plotly.graph_objects as go


data = pathlib.Path(os.path.abspath(__file__)).parent.parent.joinpath("results").absolute()
assert data.is_dir()
data_file = data.joinpath("opencraft-events.log")
assert data_file.is_file()
output_dir = pathlib.Path(__file__).parent.absolute()
assert output_dir.is_dir()


def parse(file_path):
    # open and read file
    with open(file_path, 'r') as f:
        lines = f.read().strip().split('\n')[1:]

    # parse lines to dict
    def parse_line(line: str):
        split_line = line.split('\t')
        return {
            'time': int(split_line[0]),
            'key': split_line[1],
            'value': split_line[2],
            'node': split_line[3],
            'iteration': int(split_line[4]),
            'config': split_line[5]
        }

    return [parse_line(line) for line in lines]


def filter_list(l, func):
    return list(filter(func, l))


def find(l, pred):
    for i, x in enumerate(l):
        if pred(x):
            return i
    return -1


def filter_before_tick(entries):
    filtered = []
    configs = set(entry['config'] for entry in entries)
    n_iter = max([entry['iteration'] for entry in entries]) + 1
    for config in configs:
        curr_entries = filter_list(entries, lambda x: x['config'] == config)
        filtered_config = []
        for iteration in range(n_iter):
            # only allow logs after the first tick to prevent noisy population data
            curr_iter_entries = filter_list(curr_entries, lambda x: x['iteration'] == iteration)
            first_tick_time = curr_iter_entries[find(curr_iter_entries, lambda x: x['key'] == 'tick')]['time']
            filtered_config.extend(filter_list(curr_iter_entries, lambda x: x['time'] > first_tick_time))

        filtered.extend(filtered_config)

    return filtered


def plot(entries):
    local_population_data = filter_list(entries, lambda x: x['key'].startswith('local_population'))
    serverless_population_data = filter_list(entries, lambda x: x['key'].startswith('serverless_population'))

    if local_population_data and serverless_population_data:
        title = 'Local vs serverless population latency'
    elif local_population_data:
        title = 'Local population latency'
    elif serverless_population_data:
        title = 'Serverless population latency'
    else:
        title = ''

    fig = go.Figure(
        layout=go.Layout(
            title=title,
            xaxis=go.layout.XAxis(
                title='Time (ms)'
            )
        )
    )

    def add_subplot(data, name):
        fig.add_trace(
            go.Box(
                x=data,
                name=name,
                boxpoints=False
            )
        )

    if local_population_data:
        n_iter = max([entry['iteration'] for entry in local_population_data]) + 1
        for it in range(n_iter):
            add_subplot([float(x['value']) for x in local_population_data if x['iteration'] == it], 'local; iteration' + str(it))
        add_subplot([float(x['value']) for x in local_population_data], 'local; combined iterations')

    if serverless_population_data:
        n_iter = max([entry['iteration'] for entry in serverless_population_data]) + 1
        for it in range(n_iter):
            add_subplot([float(x['value']) for x in serverless_population_data if x['iteration'] == it], 'serverless; iteration' + str(it))
        add_subplot([float(x['value']) for x in serverless_population_data], 'serverless; combined iterations')

    fig.write_image(str(output_dir.joinpath(f"{title.replace(' ', '_')}.pdf")))


if __name__ == '__main__':
    entries = parse(data_file)
    entries = filter_before_tick(entries)
    plot(entries)
