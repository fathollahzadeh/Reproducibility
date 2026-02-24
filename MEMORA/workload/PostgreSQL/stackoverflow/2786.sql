
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
AggregateStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(Score) AS TotalScore,
        AVG(Score) AS AvgScore,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        TopQuestions
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.Score,
    a.TotalPosts,
    a.TotalScore,
    a.AvgScore,
    a.TotalUpVotes,
    a.TotalDownVotes,
    CASE 
        WHEN tq.Score >= a.AvgScore THEN 'Above Average'
        WHEN tq.Score < a.AvgScore THEN 'Below Average'
        ELSE 'Average'
    END AS ScoreComparison,
    STRING_AGG(DISTINCT c.Text, '; ') AS CommentSummary
FROM 
    TopQuestions tq
LEFT JOIN 
    Comments c ON tq.PostId = c.PostId
CROSS JOIN 
    AggregateStats a
GROUP BY 
    tq.PostId, tq.Title, tq.CreationDate, tq.Score, a.TotalPosts, a.TotalScore, a.AvgScore, a.TotalUpVotes, a.TotalDownVotes
ORDER BY 
    tq.Score DESC;
