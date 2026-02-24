WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
), 
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pb.TotalPosts, 0) AS TotalPosts,
        COALESCE(ub.TotalBadges, 0) AS TotalBadges,
        pb.AverageScore,
        CASE 
            WHEN COALESCE(pb.TotalPosts, 0) = 0 THEN 'No Posts'
            WHEN COALESCE(ub.TotalBadges, 0) > 10 THEN 'Highly Acclaimed'
            ELSE 'Average Contributor' 
        END AS UserContributionLevel
    FROM Users u
    LEFT JOIN PostStatistics pb ON u.Id = pb.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (10, 12) THEN 1 ELSE 0 END) AS DeleteVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalBadges,
    u.UserContributionLevel,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.DeleteVotes,
    CASE 
        WHEN ps.DeleteVotes > 0 THEN 'Deleted'
        WHEN ps.UpVotes > ps.DownVotes THEN 'Favorably Received'
        ELSE 'Unfavorably Received'
    END AS PostReception
FROM UserPerformance u
LEFT JOIN Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN PostVoteStats ps ON p.Id = ps.PostId
WHERE u.TotalPosts > 0
ORDER BY u.UserId, p.CreationDate DESC;
