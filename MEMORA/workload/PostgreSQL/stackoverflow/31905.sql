
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        (SELECT u.DisplayName FROM Users u WHERE u.Id = p.OwnerUserId) AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.Score, p.CreationDate, p.ViewCount
    HAVING 
        COUNT(c.Id) > 5 OR SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10
    ORDER BY 
        p.Score DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ue.DisplayName AS EngagedUser,
    ue.VoteCount,
    ue.CommentCount,
    pp.TotalComments,
    pp.UpVotes,
    pp.DownVotes,
    pp.OwnerDisplayName
FROM 
    RankedPosts rp
JOIN 
    UserEngagement ue ON ue.UserId IN (
        SELECT UserId 
        FROM Votes 
        WHERE PostId = rp.PostId 
          AND VoteTypeId IN (2, 3) 
        GROUP BY UserId 
        HAVING COUNT(*) > 5
    )
JOIN 
    PopularPosts pp ON pp.Id = rp.PostId
ORDER BY 
    rp.Rank, ue.VoteCount DESC;
