WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 4 THEN 1 ELSE 0 END), 0) AS OffensiveVotes,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PopularQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS PopularityRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
RecentActivities AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (5, 4)
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title
),
CombinedStats AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        COALESCE(up.UpVotes, 0) AS TotalUpVotes,
        COALESCE(down.DownVotes, 0) AS TotalDownVotes,
        COALESCE(pq.PostId, 0) AS PopularPostId,
        COALESCE(pq.Title, 'N/A') AS PopularPostTitle,
        COALESCE(pq.Score, 0) AS PopularPostScore,
        COALESCE(ra.CommentCount, 0) AS RecentCommentCount,
        COALESCE(ra.LastCommentDate, '1900-01-01') AS LastCommentDate
    FROM 
        UserVoteStats u
    LEFT JOIN 
        UserVoteStats up ON u.UserId = up.UserId AND up.UpVotes > 0
    LEFT JOIN 
        UserVoteStats down ON u.UserId = down.UserId AND down.DownVotes > 0
    LEFT JOIN 
        PopularQuestions pq ON pq.PopularityRank = 1
    LEFT JOIN 
        RecentActivities ra ON ra.PostId IS NOT NULL AND ra.CommentCount > 0
)
SELECT 
    cs.DisplayName,
    cs.TotalUpVotes,
    cs.TotalDownVotes,
    cs.PopularPostTitle,
    cs.PopularPostScore,
    cs.RecentCommentCount,
    (CASE 
        WHEN cs.TotalUpVotes > cs.TotalDownVotes THEN 'Active User'
        WHEN cs.TotalUpVotes = cs.TotalDownVotes THEN 'Neutral'
        ELSE 'Inactive User' 
    END) AS UserActivityStatus,
    (SELECT 
        STRING_AGG(DISTINCT COALESCE(t.TagName, 'No Tags'), ', ') 
     FROM 
        Posts p 
     LEFT JOIN 
        Tags t ON p.Id = t.ExcerptPostId 
     WHERE 
        p.OwnerUserId = cs.UserId) AS UserTags
FROM 
    CombinedStats cs
WHERE 
    cs.TotalUpVotes > 0 OR cs.TotalDownVotes > 0
ORDER BY 
    cs.TotalUpVotes DESC, cs.TotalDownVotes ASC
LIMIT 50;