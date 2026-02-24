WITH UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 0 
    GROUP BY 
        u.Id, u.Reputation
),
PostStatsCTE AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                                  SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes
         GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.OwnerUserId, v.UpVotes, v.DownVotes
),
BannedUsers AS (
    SELECT 
        u.Id AS UserId
    FROM 
        Users u
    WHERE 
        u.Reputation < 0 
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(ur.PostCount, 0) AS PostCount,
    COALESCE(ur.QuestionCount, 0) AS QuestionCount,
    COALESCE(ur.AnswerCount, 0) AS AnswerCount,
    COALESCE(ur.BadgeCount, 0) AS BadgeCount,
    COALESCE(ps.CommentCount, 0) AS CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    CASE 
        WHEN bu.UserId IS NOT NULL THEN 'Banned'
        ELSE 'Active' 
    END AS UserStatus
FROM 
    Users u
LEFT JOIN 
    UserReputationCTE ur ON u.Id = ur.UserId
LEFT JOIN 
    PostStatsCTE ps ON u.Id = ps.OwnerUserId AND ps.RecentPostRank = 1
LEFT JOIN 
    BannedUsers bu ON u.Id = bu.UserId
WHERE 
    (ur.PostCount > 0 OR bu.UserId IS NOT NULL) 
ORDER BY 
    u.Reputation DESC, 
    ps.CommentCount DESC NULLS LAST;