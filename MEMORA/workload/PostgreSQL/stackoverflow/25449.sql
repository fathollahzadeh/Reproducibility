
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LatestChangeDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS RecentEdits
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        ROW_NUMBER() OVER (ORDER BY t.Count DESC) AS TagRank
    FROM 
        Tags t
    WHERE 
        t.Count > 0
)
SELECT 
    ua.DisplayName,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.UpVotes,
    ua.DownVotes,
    rph.LatestChangeDate,
    rph.RecentEdits,
    pt.TagName,
    pt.Count AS TagUsageCount
FROM 
    UserActivity ua
LEFT JOIN 
    RecentPostHistory rph ON ua.UserId = rph.PostId
LEFT JOIN 
    PopularTags pt ON ua.UserRank = pt.TagRank
WHERE 
    ua.UserRank <= 10
ORDER BY 
    ua.UpVotes DESC, ua.QuestionCount DESC;
