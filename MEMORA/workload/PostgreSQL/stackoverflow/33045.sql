WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        MAX(u.LastAccessDate) AS LastActive
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
), 
HighActivityUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.QuestionsCount,
        ua.AnswersCount,
        ua.LastActive
    FROM 
        UserActivity ua
    WHERE 
        ua.LastActive > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND ua.TotalPosts > 10
)

SELECT 
    u.UserId,
    u.DisplayName,
    ph.PostId,
    ph.UserDisplayName AS EditorName,
    ph.CreationDate AS EditDate,
    ph.Comment AS EditComment,
    p.Title,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.Tags,
    COALESCE(pvs.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(pvs.TotalDownVotes, 0) AS TotalDownVotes,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    CASE
        WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
        ELSE 'Other Edits'
    END AS EditType
FROM 
    RecursivePostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    HighActivityUsers u ON ph.UserId = u.UserId
LEFT JOIN 
    PostVoteSummary pvs ON p.Id = pvs.PostId
WHERE 
    ph.rn = 1 
    AND ph.PostHistoryTypeId IN (10, 11, 6)
ORDER BY 
    u.TotalPosts DESC, 
    ph.CreationDate DESC;