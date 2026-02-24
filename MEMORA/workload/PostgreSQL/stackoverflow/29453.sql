
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS WikiCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT 
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.WikiCount,
    ue.DisplayName AS UserEngaged,
    ue.CommentCount,
    ue.UpVotes,
    ue.DownVotes,
    phd.UserDisplayName AS HistoryUser,
    phd.CreationDate AS HistoryDate,
    phd.Comment AS HistoryComment,
    phd.Text AS HistoryDetail
FROM 
    TagStatistics ts
LEFT JOIN 
    UserEngagement ue ON ue.UpVotes > 0 OR ue.DownVotes > 0 
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.Tags LIKE CONCAT('%', ts.TagName, '%')
        ORDER BY p.LastActivityDate DESC 
        LIMIT 1
    )
ORDER BY 
    ts.PostCount DESC, ue.CommentCount DESC, phd.CreationDate DESC;
