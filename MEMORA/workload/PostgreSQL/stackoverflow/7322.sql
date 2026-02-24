
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(vs.UpVoteScore, 0) AS UpVoteCount,
        COALESCE(vs.DownVoteScore, 0) AS DownVoteCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteScore,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteScore
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vs ON p.Id = vs.PostId
    WHERE 
        p.PostTypeId = 1 
),
LastActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        MAX(p.LastActivityDate) AS LastActiveDate
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.CommentCount,
    lau.DisplayName AS OwnerDisplayName,
    lau.LastActiveDate
FROM 
    RankedPosts rp
JOIN 
    LastActiveUsers lau ON rp.PostId = lau.UserId
WHERE 
    rp.RowNum <= 10 
ORDER BY 
    rp.CreationDate DESC;
