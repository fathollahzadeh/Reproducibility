
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserPostCounts
),
LatestPosts AS (
    SELECT 
        p.*,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryWithTags AS (
    SELECT 
        ph.PostId,
        STRING_AGG(t.TagName, ', ') AS Tags,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '<>')) AS tag ON tag IS NOT NULL 
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    pp.LastEditDate,
    p.Tags,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN tu.UserRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory,
    pp.Body AS MostRecentPostBody
FROM 
    TopUsers tu
LEFT JOIN 
    LatestPosts pp ON tu.UserId = pp.OwnerUserId AND pp.rn = 1
LEFT JOIN 
    PostHistoryWithTags p ON pp.Id = p.PostId
LEFT JOIN 
    PostVotes pv ON pp.Id = pv.PostId
WHERE 
    tu.PostCount > 0
    AND (p.LastEditDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' OR p.LastEditDate IS NULL)
ORDER BY 
    tu.PostCount DESC, tu.DisplayName;
