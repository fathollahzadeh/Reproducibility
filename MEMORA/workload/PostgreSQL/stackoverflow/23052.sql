
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(p.AnswerCount, 0) AS AnswerCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' AND
        p.PostTypeId = 1
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.ViewCount,
        rp.AnswerCount,
        COALESCE(ph.PostHistoryTypeId, 0) AS LastHistoryType,
        COALESCE(ph.CreationDate, CAST('1970-01-01' AS TIMESTAMP)) AS LastHistoryDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    WHERE 
        rp.Rank = 1
),
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.ViewCount,
    pd.AnswerCount,
    ts.TagName,
    COALESCE(ub.GoldBadges, 0) AS UserGoldBadges,
    COALESCE(ub.SilverBadges, 0) AS UserSilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS UserBronzeBadges,
    CASE 
        WHEN pd.LastHistoryType IS NULL THEN 'No History'
        ELSE 
            CASE 
                WHEN pd.LastHistoryType = 10 THEN 'Closed'
                WHEN pd.LastHistoryType = 11 THEN 'Reopened'
                ELSE 'Other Action'
            END
    END AS LastAction,
    CASE 
        WHEN pd.LastHistoryDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days' THEN 'Recently Updated'
        ELSE 'Stale'
    END AS UpdateStatus
FROM 
    PostDetails pd
LEFT JOIN 
    TagStats ts ON ts.PostCount > 0
LEFT JOIN 
    UserBadges ub ON ub.UserId = pd.PostId
WHERE 
    pd.ViewCount > (SELECT AVG(ViewCount) FROM Posts) AND 
    (pd.AnswerCount > 0 OR pd.LastHistoryType IN (10, 11))
ORDER BY 
    pd.ViewCount DESC
LIMIT 100;
