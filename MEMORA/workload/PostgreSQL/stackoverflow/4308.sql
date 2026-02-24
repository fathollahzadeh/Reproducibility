
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopQuestions AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        Score,
        ViewCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn <= 10
),
HelpfulComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS HelpfulCount
    FROM 
        Comments c
    WHERE 
        LOWER(c.Text) LIKE '%helpful%' 
    GROUP BY 
        c.PostId
)
SELECT 
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.ViewCount,
    tq.UpVotes,
    tq.DownVotes,
    COALESCE(hc.HelpfulCount, 0) AS HelpfulCommentsCount,
    CASE 
        WHEN tq.Score >= 10 THEN 'High Score'
        WHEN tq.Score BETWEEN 5 AND 9 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    TopQuestions tq
LEFT JOIN 
    Posts p ON tq.Id = p.Id
LEFT JOIN 
    HelpfulComments hc ON tq.Id = hc.PostId
ORDER BY 
    tq.Score DESC, tq.CreationDate DESC;
