
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.UserId, 
        ph.PostId, 
        p.Title, 
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN ph.CreationDate END) AS LastContentEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        ph.UserId, ph.PostId, p.Title
),
FinalStats AS (
    SELECT 
        us.UserId, 
        us.DisplayName, 
        us.PostCount, 
        us.QuestionCount, 
        us.AnswerCount, 
        us.UpVotes, 
        us.DownVotes, 
        us.BadgeCount,
        COUNT(DISTINCT phd.PostId) AS EditedPostsCount,
        COUNT(DISTINCT phd.PostId) FILTER (WHERE phd.LastClosedDate IS NOT NULL) AS ClosedPostsCount
    FROM 
        UserStats us
    LEFT JOIN 
        PostHistoryDetails phd ON us.UserId = phd.UserId
    GROUP BY 
        us.UserId, us.DisplayName, us.PostCount, us.QuestionCount, us.AnswerCount, 
        us.UpVotes, us.DownVotes, us.BadgeCount
)
SELECT 
    UserId, 
    DisplayName, 
    PostCount, 
    QuestionCount, 
    AnswerCount, 
    UpVotes, 
    DownVotes, 
    BadgeCount, 
    EditedPostsCount, 
    ClosedPostsCount
FROM 
    FinalStats
ORDER BY 
    PostCount DESC, UpVotes DESC
LIMIT 10;
