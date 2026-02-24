
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY SUM(u.UpVotes) - SUM(u.DownVotes) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgPostAgeInSeconds
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.BadgeCount,
        ps.TotalPosts,
        ps.QuestionsCount,
        ps.AnswersCount,
        (us.TotalUpVotes - us.TotalDownVotes) AS NetVotes
    FROM 
        UserStats us
    JOIN 
        PostSummary ps ON us.UserId = ps.OwnerUserId
    WHERE 
        us.UserRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.BadgeCount,
    tu.TotalPosts,
    tu.QuestionsCount,
    tu.AnswersCount,
    (CASE 
        WHEN tu.NetVotes IS NULL THEN 'No Votes' 
        ELSE CONCAT(CAST(tu.NetVotes AS TEXT), ' Net Votes') 
    END) AS VoteSummary,
    COALESCE(p.Title, 'No Recent Post') AS RecentPostTitle,
    (SELECT 
        COUNT(*) 
     FROM 
        Comments c 
     WHERE 
        c.UserId = tu.UserId) AS CommentCount
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId 
              AND p.CreationDate = (SELECT MAX(CreationDate) 
                                     FROM Posts 
                                     WHERE OwnerUserId = tu.UserId)
ORDER BY 
    tu.BadgeCount DESC, 
    tu.NetVotes DESC;
