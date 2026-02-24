
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, p.PostTypeId
),
MostCommented AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT b.Id) > 0 OR SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 0
)
SELECT 
    mc.PostId,
    mc.Title,
    mc.CreationDate,
    mc.ViewCount,
    mc.OwnerDisplayName,
    mc.CommentCount,
    tu.DisplayName AS TopUserDisplayName,
    tu.BadgeCount,
    tu.UpVotesCount
FROM 
    MostCommented mc
JOIN 
    TopUsers tu ON mc.OwnerDisplayName = tu.DisplayName
ORDER BY 
    mc.ViewCount DESC, mc.CommentCount DESC;
