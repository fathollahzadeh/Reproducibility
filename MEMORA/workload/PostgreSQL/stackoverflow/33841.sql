WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        U.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
        LEFT JOIN Users U ON p.OwnerUserId = U.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, U.DisplayName, p.CreationDate
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerName,
        CommentCount,
        UpVotes,
        DownVotes,
        (UpVotes - DownVotes) AS NetVotes,
        CASE 
            WHEN CommentCount > 10 THEN 'Highly Interactive'
            WHEN CommentCount BETWEEN 5 AND 10 THEN 'Moderately Interactive'
            ELSE 'Less Interactive'
        END AS InteractionLevel
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostAnalytics AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        pp.OwnerName,
        pp.CommentCount,
        pp.UpVotes,
        pp.DownVotes,
        pp.NetVotes,
        pp.InteractionLevel,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        PopularPosts pp
        LEFT JOIN UserBadges ub ON pp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = ub.UserId)
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.OwnerName,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.NetVotes,
    pa.InteractionLevel,
    COALESCE(pa.BadgeCount, 0) AS BadgeCount,
    COALESCE(pa.GoldBadges, 0) AS GoldBadges,
    COALESCE(pa.SilverBadges, 0) AS SilverBadges,
    COALESCE(pa.BronzeBadges, 0) AS BronzeBadges,
    (ROW_NUMBER() OVER (ORDER BY pa.NetVotes DESC, pa.CommentCount DESC)) AS Rank
FROM 
    PostAnalytics pa
ORDER BY 
    pa.NetVotes DESC,
    pa.CommentCount DESC
LIMIT 50;