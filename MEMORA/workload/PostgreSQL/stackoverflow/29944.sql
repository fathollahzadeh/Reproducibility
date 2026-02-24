WITH TagMetrics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        Votes v ON v.PostId = p.Id AND v.UserId = u.Id
    WHERE 
        p.PostTypeId = 2  
    GROUP BY 
        u.Id, u.DisplayName
),
CombinedMetrics AS (
    SELECT 
        tm.TagName,
        tm.PostCount,
        tm.CloseCount,
        tm.ReopenCount,
        ue.UserId,
        ue.DisplayName,
        ue.AnswerCount,
        ue.UpVotes,
        ue.DownVotes
    FROM 
        TagMetrics tm
    CROSS JOIN 
        UserEngagement ue
)
SELECT 
    c.TagName,
    c.PostCount,
    c.CloseCount,
    c.ReopenCount,
    c.UserId,
    c.DisplayName,
    c.AnswerCount,
    c.UpVotes,
    c.DownVotes,
    RANK() OVER (ORDER BY c.PostCount DESC) AS TagRank
FROM 
    CombinedMetrics c
ORDER BY 
    c.PostCount DESC, c.CloseCount DESC, c.ReopenCount DESC, c.UserId;