
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(EXTRACT(EPOCH FROM p.CreationDate AT TIME ZONE 'UTC')) AS AvgPostCreationDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS ClosedHistoryCount,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes c ON (ph.Comment::text)::int = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalViews,
    ups.TotalScore,
    pvs.Upvotes,
    pvs.Downvotes,
    cps.ClosedHistoryCount,
    cps.CloseReasons
FROM 
    UserPostStats ups
LEFT JOIN 
    PostVoteStats pvs ON ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pvs.PostId)
LEFT JOIN 
    ClosedPostStats cps ON pvs.PostId = cps.PostId
WHERE 
    ups.PostCount > 0
ORDER BY 
    ups.TotalScore DESC, ups.TotalViews DESC
LIMIT 100;
