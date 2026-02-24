
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(p.Body, ''), 'No content available') AS BodySnippet
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount,
        pb.BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        PostBadges pb ON u.Id = pb.UserId
    WHERE 
        u.Reputation > 1000
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.BodySnippet,
        tu.DisplayName,
        tu.Reputation,
        tu.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers tu ON rp.Score > 5
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.BodySnippet,
    tp.DisplayName,
    tp.Reputation,
    CASE 
        WHEN tp.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
FROM 
    TopPosts tp
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.ViewCount, tp.BodySnippet, tp.DisplayName, tp.Reputation, tp.BadgeCount
ORDER BY 
    tp.ViewCount DESC, tp.Title;
