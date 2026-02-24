
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    INNER JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS int) = crt.Id
    WHERE 
        pht.Name LIKE '%Closed%'
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    ubc.UserId,
    ubc.DisplayName,
    ubc.Reputation,
    COALESCE(ubc.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubc.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubc.BronzeBadges, 0) AS BronzeBadges,
    pq.Title AS PopularQuestionTitle,
    pq.CreationDate AS PopularQuestionDate,
    pq.Score AS PopularQuestionScore,
    cp.CloseReasons AS ClosedPostReasons
FROM 
    UserBadgeCounts ubc
LEFT JOIN 
    PopularQuestions pq ON ubc.UserId = (
        SELECT 
            p.OwnerUserId
        FROM 
            Posts p
        WHERE 
            p.PostTypeId = 1 
            AND p.Score > 0
        ORDER BY 
            p.ViewCount DESC
        LIMIT 1
    )
LEFT JOIN 
    ClosedPosts cp ON pq.PostId = cp.PostId
WHERE 
    ubc.Reputation > 1000
ORDER BY 
    ubc.Reputation DESC,
    pq.Score DESC NULLS LAST;
