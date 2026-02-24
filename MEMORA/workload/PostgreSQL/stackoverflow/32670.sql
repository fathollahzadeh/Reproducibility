
WITH RecursiveTagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseInstance
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        ClosedPosts CP ON p.Id = CP.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, CP.CloseReason
),
TopTags AS (
    SELECT 
        rtc.TagName,
        rtc.PostCount,
        ROW_NUMBER() OVER (ORDER BY rtc.PostCount DESC) AS TagRank
    FROM 
        RecursiveTagCounts rtc
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.ReputationRank,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.CloseReason,
    pp.CommentCount,
    pp.UpVotes,
    pp.DownVotes,
    tt.TagName,
    tt.PostCount AS TagPostCount
FROM 
    UserReputation up
JOIN 
    PopularPosts pp ON pp.CommentCount > 5
LEFT JOIN 
    TopTags tt ON pp.Title ILIKE CONCAT('%', tt.TagName, '%')
WHERE 
    up.ReputationRank <= 10
ORDER BY 
    up.Reputation DESC, pp.Score DESC, pp.ViewCount DESC;
