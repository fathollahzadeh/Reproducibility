WITH PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        VoteCount,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (PARTITION BY (CASE WHEN Score > 0 THEN 'Positive' ELSE 'Non-Positive' END) ORDER BY Score DESC) AS Rank
    FROM
        PostMetrics
)
SELECT
    tt.PostId,
    tt.Title,
    tt.CreationDate,
    tt.Score,
    tt.ViewCount,
    tt.CommentCount,
    tt.VoteCount,
    tt.UpVotes,
    tt.DownVotes,
    CASE 
        WHEN tt.Score IS NULL THEN 'No Score'
        WHEN tt.Score > 100 THEN 'Very Popular'
        WHEN tt.Score > 50 THEN 'Popular'
        WHEN tt.Score > 0 THEN 'Some Interest'
        ELSE 'Not Popular' 
    END AS Popularity,
    COALESCE(pm.Name, 'Unknown') AS PostType
FROM
    TopPosts tt
LEFT JOIN PostTypes pm ON (CASE 
    WHEN tt.Score > 0 THEN 1
    ELSE 2 
END) = pm.Id
WHERE
    tt.Rank <= 10
ORDER BY 
    tt.Score DESC;