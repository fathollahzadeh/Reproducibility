
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS Owner,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.Comment AS HistoryComment,
        p.Title,
        p.OwnerDisplayName,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CommentRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>') 
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Owner,
    rp.Tags,
    rph.HistoryComment AS LastActionComment,
    rph.HistoryDate AS LastActionDate,
    mau.DisplayName AS ActiveUser,
    mau.VoteCount AS UserVotes,
    tt.TagName AS MostUsedTag,
    tt.PostCount AS TagPostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId AND rph.CommentRank = 1
LEFT JOIN 
    MostActiveUsers mau ON mau.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
JOIN 
    TopTags tt ON tt.TagName = ANY(string_to_array(rp.Tags, ','))
WHERE 
    rp.TagRank <= 5
ORDER BY 
    rp.CreationDate DESC, rp.ViewCount DESC;
