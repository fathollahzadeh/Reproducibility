WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
    WHERE 
        p.PostTypeId = 2  
),
PostDetails AS (
    SELECT
        ph.PostId,
        ph.Title,
        ph.Level,
        p.CreationDate,
        p.Score,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        PostHierarchy ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        ph.PostId, ph.Title, ph.Level, p.CreationDate, p.Score
),
Ranking AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.Level,
        PD.CreationDate,
        PD.Score,
        PD.CommentCount,
        PD.UpVotes,
        PD.DownVotes,
        RANK() OVER (ORDER BY PD.Score DESC) AS ScoreRank
    FROM 
        PostDetails PD
)
SELECT 
    R.PostId,
    R.Title,
    R.Level,
    R.CreationDate,
    R.Score,
    R.CommentCount,
    R.UpVotes,
    R.DownVotes,
    R.ScoreRank
FROM 
    Ranking R
WHERE 
    R.Level = 2  
    AND R.UpVotes > R.DownVotes  
ORDER BY 
    R.ScoreRank;