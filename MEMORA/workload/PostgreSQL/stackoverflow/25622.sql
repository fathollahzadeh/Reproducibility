
WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        ARRAY_LENGTH(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '>'), 1) AS TagCount,
        COUNT(co.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Posts p
    LEFT JOIN
        Comments co ON p.Id = co.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id
),
PostHistoryAnalysis AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY
        ph.PostId, ph.PostHistoryTypeId
),
CombinedPostData AS (
    SELECT
        pt.PostId,
        pt.TagCount,
        pt.CommentCount,
        pt.UpVotes,
        pt.DownVotes,
        COALESCE(pha.ChangeCount, 0) AS EditCount,
        ROW_NUMBER() OVER (ORDER BY pt.UpVotes DESC, pt.CommentCount DESC) AS Rank
    FROM
        PostTagCounts pt
    LEFT JOIN
        PostHistoryAnalysis pha ON pt.PostId = pha.PostId
)
SELECT
    p.Id AS PostId,
    p.Title,
    p.Tags,
    cp.TagCount,
    cp.CommentCount,
    cp.UpVotes,
    cp.DownVotes,
    cp.EditCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    cp.Rank
FROM
    CombinedPostData cp
JOIN
    Posts p ON cp.PostId = p.Id
JOIN
    Users u ON p.OwnerUserId = u.Id
WHERE
    cp.Rank <= 10  
ORDER BY
    cp.Rank;
