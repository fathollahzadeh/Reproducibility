WITH UserActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(p.Id) AS TotalPosts, 
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.CreationDate >= '2023-01-01'
    GROUP BY u.Id, u.DisplayName
), BadgeCount AS (
    SELECT UserId, 
           COUNT(*) AS TotalBadges
    FROM Badges
    GROUP BY UserId
), RankActivity AS (
    SELECT ua.UserId, 
           ua.DisplayName, 
           ua.TotalPosts, 
           ua.Questions, 
           ua.Answers,
           ua.UpVotes, 
           ua.DownVotes, 
           COALESCE(bc.TotalBadges, 0) AS TotalBadges,
           RANK() OVER (ORDER BY ua.UpVotes DESC, ua.TotalPosts DESC) AS ActivityRank
    FROM UserActivity ua
    LEFT JOIN BadgeCount bc ON ua.UserId = bc.UserId
)
SELECT ra.UserId, 
       ra.DisplayName, 
       ra.TotalPosts, 
       ra.Questions, 
       ra.Answers, 
       ra.UpVotes, 
       ra.DownVotes, 
       ra.TotalBadges, 
       ra.ActivityRank
FROM RankActivity ra
WHERE ra.ActivityRank <= 10
ORDER BY ra.ActivityRank;
