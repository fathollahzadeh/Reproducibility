WITH RECURSIVE UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        OwnerUserId
    UNION ALL
    SELECT 
        UserId,
        COUNT(*)
    FROM 
        Comments
    WHERE 
        CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        UserId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE 
            WHEN Class = 1 THEN 1 
            ELSE 0 
        END) AS GoldBadges,
        SUM(CASE 
            WHEN Class = 2 THEN 1 
            ELSE 0 
        END) AS SilverBadges,
        SUM(CASE 
            WHEN Class = 3 THEN 1 
            ELSE 0 
        END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        p.Title,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        ph.UserId, ph.PostId, ph.CreationDate, p.Title, p.Score
),
VoteSummary AS (
    SELECT 
        p.OwnerUserId,
        SUM(CASE 
            WHEN v.VoteTypeId IN (2) THEN 1 
            ELSE 0 
        END) AS TotalUpVotes,
        SUM(CASE 
            WHEN v.VoteTypeId IN (3) THEN 1 
            ELSE 0 
        END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(UPC.PostCount, 0) AS PostsInLastYear,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PS.TotalUpVotes, 0) AS UpVotes,
    COALESCE(PS.TotalDownVotes, 0) AS DownVotes,
    COUNT(DISTINCT PHD.PostId) AS PostsWithHistory
FROM 
    Users u
LEFT JOIN 
    UserPostCounts UPC ON u.Id = UPC.OwnerUserId
LEFT JOIN 
    UserBadges UB ON u.Id = UB.UserId
LEFT JOIN 
    VoteSummary PS ON u.Id = PS.OwnerUserId
LEFT JOIN 
    PostHistoryDetails PHD ON u.Id = PHD.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, UPC.PostCount, 
    UB.BadgeCount, UB.GoldBadges, UB.SilverBadges, 
    UB.BronzeBadges, PS.TotalUpVotes, PS.TotalDownVotes
ORDER BY 
    u.Reputation DESC
LIMIT 20;