WITH RECURSIVE PostChain AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        a.Score,
        pc.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts p ON a.ParentId = p.Id
    INNER JOIN 
        PostChain pc ON p.Id = pc.PostId
)
SELECT 
    pc.PostId,
    pc.Title,
    u.DisplayName AS OwnerDisplayName,
    pc.CreationDate,
    pc.Score AS QuestionScore,
    COALESCE(SUM(sub.UpVoteCount), 0) AS TotalUpVotes,
    COALESCE(SUM(sub.DownVoteCount), 0) AS TotalDownVotes,
    CASE 
        WHEN nc.Clicks IS NOT NULL THEN 'Clicked' 
        ELSE 'Not Clicked' 
    END AS NotificationClickStatus
FROM 
    PostChain pc
LEFT JOIN 
    Users u ON pc.OwnerUserId = u.Id
LEFT JOIN 
    (
        SELECT 
            PostId,
            COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVoteCount,
            COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVoteCount
        FROM 
            Votes v
        INNER JOIN 
            VoteTypes vt ON v.VoteTypeId = vt.Id
        GROUP BY 
            PostId
    ) sub ON pc.PostId = sub.PostId
LEFT JOIN 
    (
        SELECT 
            PostId,
            COUNT(*) AS Clicks
        FROM 
            PostLinks pl
        WHERE 
            pl.LinkTypeId = 1 
        GROUP BY 
            PostId
    ) nc ON pc.PostId = nc.PostId
WHERE 
    pc.Level = 1
GROUP BY 
    pc.PostId, pc.Title, u.DisplayName, pc.CreationDate, pc.Score, nc.Clicks
ORDER BY 
    TotalUpVotes DESC, pc.Score DESC
LIMIT 100;