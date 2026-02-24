WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        COALESCE((SELECT COUNT(*) 
                  FROM Votes v 
                  WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)), 0) AS TotalVotes,
        ARRAY_LENGTH(string_to_array(COALESCE(p.Tags, ''), '><'), 1) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.ViewCount IS NOT NULL
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        r.OwnerUserId,
        AVG(r.Score) AS AvgScore,
        SUM(r.ViewCount) AS TotalViews,
        COUNT(*) AS PostsCount,
        COUNT(CASE WHEN r.Rank = 1 THEN 1 END) AS AcceptedAnswers
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 10
    GROUP BY 
        r.OwnerUserId
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        b.Class AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users)
),
RecentCloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= DATE_TRUNC('month', cast('2024-10-01 12:34:56' as timestamp))
    GROUP BY 
        ph.PostId, ph.Comment
),
FinalResults AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ps.AvgScore,
        ps.TotalViews,
        ps.PostsCount,
        ps.AcceptedAnswers,
        CASE 
            WHEN rc.CloseCount IS NULL THEN 'Not Closed' 
            ELSE 'Closed' 
        END AS RecentCloseStatus,
        rc.Comment AS RecentCloseComment
    FROM 
        UserWithBadges ub
    JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
    LEFT JOIN 
        RecentCloseReasons rc ON rc.PostId = (SELECT MAX(Id) FROM Posts WHERE OwnerUserId = ub.UserId)
)
SELECT 
    UserId,
    DisplayName,
    AvgScore,
    TotalViews,
    PostsCount,
    AcceptedAnswers,
    RecentCloseStatus,
    RecentCloseComment
FROM 
    FinalResults
WHERE 
    AvgScore > 0
ORDER BY 
    AvgScore DESC, TotalViews DESC
LIMIT 100;