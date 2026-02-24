
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
),
AggregatedData AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        RankedPosts r
    JOIN Posts p ON r.PostId = p.Id
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CombinedResults AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ad.TotalPosts, 0) AS PostCount,
        COALESCE(ad.TotalScore, 0) AS TotalScore,
        COALESCE(ad.AverageViews, 0) AS AverageViews,
        COALESCE(ub.BadgeNames, 'No Badges') AS Badges,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        AggregatedData ad ON u.Id = ad.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    AverageViews,
    Badges,
    BadgeCount,
    CASE 
        WHEN PostCount > 10 THEN 'High Contributor'
        WHEN PostCount BETWEEN 5 AND 10 THEN 'Moderate Contributor'
        ELSE 'Newbie Contributor'
    END AS ContributorRank,
    EXISTS (
        SELECT 1
        FROM Posts p
        WHERE 
            p.OwnerUserId = UserId AND 
            p.ClosedDate IS NULL AND 
            p.PostTypeId = 1 
            AND p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)
    ) AS HasHighScoringOpenQuestions
FROM 
    CombinedResults
ORDER BY 
    TotalScore DESC, 
    PostCount DESC;
