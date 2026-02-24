
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
Summary AS (
    SELECT 
        COUNT(DISTINCT ps.PostId) AS TotalPosts,
        SUM(ps.Score) AS TotalScore,
        AVG(ps.ViewCount) AS AvgViewCount,
        SUM(us.BadgeCount) AS TotalBadges,
        SUM(us.TotalUpVotes) AS OverallUpVotes,
        SUM(us.TotalDownVotes) AS OverallDownVotes
    FROM 
        PostStats ps
    JOIN 
        UserStats us ON ps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = us.UserId)
)

SELECT 
    TotalPosts,
    TotalScore,
    AvgViewCount,
    TotalBadges,
    OverallUpVotes,
    OverallDownVotes
FROM 
    Summary;
