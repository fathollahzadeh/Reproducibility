WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        pd.RevisionGUID,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY pd.CreationDate DESC) AS RecentEditRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory pd ON p.Id = pd.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(MAX(v.CreationDate), '1970-01-01') AS LastVoteDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        rp.RecentEditRank = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount
),
TopBadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tq.Title AS QuestionTitle,
    tq.ViewCount,
    tu.DisplayName AS UserName,
    tu.BadgeCount AS TotalBadges,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    tq.LastVoteDate
FROM 
    TopQuestions tq
JOIN 
    Posts p ON tq.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    TopBadgedUsers tu ON u.Id = tu.UserId
WHERE 
    tq.ViewCount > 1000
ORDER BY 
    tq.ViewCount DESC,
    tq.LastVoteDate DESC
LIMIT 10;