WITH PostOwnerStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        bs.PostCount,
        bs.QuestionCount,
        bs.AnswerCount,
        bs.AvgScore,
        bs.LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        PostOwnerStats bs ON u.Id = bs.OwnerUserId
),
TopBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.Views,
        us.UpVotes,
        us.DownVotes,
        COALESCE(tb.Badges, 'No Badges') AS Badges,
        COALESCE(tb.BadgeCount, 0) AS BadgeCount,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.AvgScore,
        us.LastPostDate
    FROM 
        UserStats us
    LEFT JOIN 
        TopBadges tb ON us.UserId = tb.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    Views,
    UpVotes,
    DownVotes,
    Badges,
    BadgeCount,
    PostCount,
    QuestionCount,
    AnswerCount,
    AvgScore,
    LastPostDate
FROM 
    FinalStats
WHERE 
    (PostCount > 5 OR BadgeCount > 3) 
    AND Reputation > 100 
ORDER BY 
    AvgScore DESC,
    QuestionCount DESC,
    AnswerCount DESC;
