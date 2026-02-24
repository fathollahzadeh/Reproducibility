WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Score,
        r.Rank,
        COALESCE(r.CommentCount, 0) AS CommentCount,
        r.UpVotes,
        r.DownVotes,
        CASE 
            WHEN r.UpVotes > r.DownVotes THEN 'Positive'
            WHEN r.DownVotes > r.UpVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 5
),
AggPostData AS (
    SELECT 
        f.Title,
        SUM(f.Score) AS TotalScore,
        AVG(f.UpVotes - f.DownVotes) AS AvgVoteDifference,
        STRING_AGG(f.Sentiment, ', ') AS SentimentList
    FROM 
        FilteredPosts f
    GROUP BY 
        f.Title
)
SELECT 
    a.Title,
    a.TotalScore,
    a.AvgVoteDifference,
    CASE 
        WHEN a.AvgVoteDifference > 0 THEN 'Generally Positive'
        WHEN a.AvgVoteDifference < 0 THEN 'Generally Negative'
        ELSE 'Balanced'
    END AS OverallSentiment,
    CASE 
        WHEN a.TotalScore IS NULL THEN 'No Activity'
        ELSE 'Active'
    END AS PostActivity
FROM 
    AggPostData a
WHERE 
    EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.Title LIKE '%' || a.Title || '%'
        AND p.CreationDate BETWEEN cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' AND cast('2024-10-01 12:34:56' as timestamp)
    )
ORDER BY 
    a.TotalScore DESC NULLS LAST;