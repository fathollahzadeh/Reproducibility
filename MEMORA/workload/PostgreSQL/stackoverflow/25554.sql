
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.badge_count, 0) AS BadgeCount,
        COALESCE(p.post_count, 0) AS PostCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS badge_count 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            OwnerUserId AS UserId,
            COUNT(*) AS post_count 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 1
        GROUP BY 
            OwnerUserId
    ) p ON u.Id = p.UserId
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        PostCount
    FROM 
        UserReputation
    ORDER BY 
        Reputation DESC, 
        BadgeCount DESC, 
        PostCount DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.ViewCount > 100 
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.BadgeCount,
    u.PostCount,
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.CreationDate
FROM 
    TopUsers u
JOIN 
    PostDetails pd ON u.UserId = pd.OwnerUserId
ORDER BY 
    u.Reputation DESC, 
    pd.ViewCount DESC;
