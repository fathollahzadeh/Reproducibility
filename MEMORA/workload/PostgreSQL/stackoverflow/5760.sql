
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        RANK() OVER (ORDER BY PostCount DESC, UpVotes DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    a.DisplayName,
    a.PostCount,
    a.QuestionCount,
    a.AnswerCount,
    a.UpVotes,
    a.DownVotes,
    a.BadgeCount,
    ps.Name AS PostStatus,
    ph.CreationDate AS LastPostEditDate
FROM 
    ActiveUsers a
JOIN 
    Posts p ON a.UserId = p.OwnerUserId
JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    PostHistoryTypes ps ON ph.PostHistoryTypeId = ps.Id
WHERE 
    ph.CreationDate = (
        SELECT MAX(ph2.CreationDate) 
        FROM PostHistory ph2 
        WHERE ph2.PostId = p.Id
    )
ORDER BY 
    a.UserRank, a.DisplayName;
