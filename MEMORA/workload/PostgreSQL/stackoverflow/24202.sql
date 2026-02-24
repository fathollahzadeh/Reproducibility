
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        p.Tags,
        COALESCE(Answers.AnswerCount, 0) AS AnswerCount,
        CASE 
            WHEN p.PostTypeId = 1 THEN (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2)
            ELSE NULL 
        END AS UpVotes,
        CASE 
            WHEN p.PostTypeId = 1 THEN (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3)
            ELSE NULL 
        END AS DownVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) AS Answers ON p.Id = Answers.ParentId
    WHERE
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
UsersRanked AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        u.Reputation,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostedTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(p.Tags, '><')) AS Tag
    FROM 
        Posts p
),
PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PostedTags 
    GROUP BY 
        Tag
    HAVING
        COUNT(*) > 10
),
PostHistoryData AS (
    SELECT 
        ph.PostId, 
        ph.UserId,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 12) THEN 1 ELSE 0 END) AS ClosedPostCount 
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.Score,
    pd.ViewCount,
    pd.AcceptedAnswerId,
    pd.AnswerCount,
    ur.DisplayName AS TopUserDisplayName,
    ur.UserRank,
    ur.BadgeCount,
    pt.Tag AS PopularTag,
    ph.LastEditDate,
    ph.CloseReason,
    ph.ClosedPostCount
FROM 
    PostDetails pd
INNER JOIN 
    UsersRanked ur ON pd.OwnerUserId = ur.UserId
LEFT JOIN 
    PostHistoryData ph ON pd.PostId = ph.PostId
LEFT JOIN 
    PopularTags pt ON pt.Tag IN (SELECT Tag FROM PostedTags WHERE PostId = pd.PostId) 
WHERE 
    pd.ViewCount >= 100
ORDER BY 
    pd.Score DESC,
    ur.UserRank ASC,
    ph.LastEditDate DESC
LIMIT 50;
