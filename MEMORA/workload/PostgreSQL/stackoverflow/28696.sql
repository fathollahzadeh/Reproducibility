WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE 
                WHEN b.Class = 1 THEN 1 
                ELSE 0 
            END) AS GoldBadges,
        SUM(CASE 
                WHEN b.Class = 2 THEN 1 
                ELSE 0 
            END) AS SilverBadges,
        SUM(CASE 
                WHEN b.Class = 3 THEN 1 
                ELSE 0 
            END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE 
                        WHEN v.VoteTypeId = 2 THEN 1 
                        WHEN v.VoteTypeId = 3 THEN -1 
                        ELSE 0 
                    END), 0) AS NetScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title
    ORDER BY 
        NetScore DESC
    LIMIT 10
)
SELECT 
    ubc.UserId,
    ubc.DisplayName,
    ubc.BadgeCount,
    tb.PostId,
    tb.Title,
    tb.CommentCount,
    tb.NetScore
FROM 
    UserBadgeCounts ubc
JOIN 
    TopPosts tb ON ubc.UserId IN (
        SELECT p.OwnerUserId
        FROM Posts p
        WHERE p.PostTypeId = 1 
    )
ORDER BY 
    ubc.BadgeCount DESC, tb.NetScore DESC;