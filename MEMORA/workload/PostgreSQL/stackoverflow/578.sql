
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.Score,
    tq.ViewCount,
    u.DisplayName AS TopUser,
    u.TotalBounties,
    u.TotalUpVotes,
    u.TotalDownVotes,
    COALESCE(pc.CommentCount, 0) AS CommentCount
FROM 
    TopQuestions tq
LEFT JOIN 
    UserStats u ON u.UserId = (
        SELECT 
            p.OwnerUserId 
        FROM 
            Posts p 
        WHERE 
            p.Id = tq.PostId
    )
LEFT JOIN 
    PostComments pc ON pc.PostId = tq.PostId
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;
