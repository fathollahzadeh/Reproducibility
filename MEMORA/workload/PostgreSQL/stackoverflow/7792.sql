WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
EngagedUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName 
    FROM 
        UserEngagement ue 
    WHERE 
        ue.CommentCount > 5 OR ue.VoteCount > 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    eu.DisplayName AS EngagedUser
FROM 
    TopPosts tp
LEFT JOIN 
    EngagedUsers eu ON tp.PostId = (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = eu.UserId 
        ORDER BY 
            p.CreationDate DESC 
        LIMIT 1
    )
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;