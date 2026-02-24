
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
ClosedPostHistory AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(ph.Id) AS CloseCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
)
SELECT 
    us.DisplayName,
    us.UpVotes,
    us.DownVotes,
    us.PostCount,
    us.CommentCount,
    us.TotalBadges,
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.Score AS PopularPostScore,
    pp.ViewCount AS PopularPostViews,
    cph.LastClosedDate,
    cph.CloseCount
FROM 
    UserStatistics us
INNER JOIN 
    PopularPosts pp ON us.UserId = pp.PostId 
LEFT JOIN 
    ClosedPostHistory cph ON pp.PostId = cph.PostId 
WHERE 
    us.Rank <= 10
ORDER BY 
    us.UpVotes DESC, 
    us.DownVotes ASC;
