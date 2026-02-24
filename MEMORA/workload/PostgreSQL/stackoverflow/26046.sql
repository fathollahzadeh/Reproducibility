WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)) AS VoteCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Comments c 
            WHERE c.PostId = p.Id 
        ), 0) AS CommentCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Posts pp 
            WHERE pp.ParentId = p.Id
        ), 0) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2)  
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        COUNT(DISTINCT ph.CreationDate) AS UniqueEditDates
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
),
RankedPosts AS (
    SELECT 
        pd.*,
        COALESCE(ph.EditCount, 0) AS EditCount,
        COALESCE(ph.UniqueEditDates, 0) AS UniqueEditDates,
        ROW_NUMBER() OVER (ORDER BY pd.ViewCount DESC, pd.LastActivityDate DESC) AS Rank
    FROM 
        PostDetails pd
    LEFT JOIN 
        PostHistoryDetails ph ON pd.PostId = ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.ViewCount,
    rp.Rank,
    rp.EditCount,
    rp.UniqueEditDates,
    rp.TagCount,
    rp.CommentCount,
    rp.AnswerCount,
    rp.CreationDate
FROM 
    RankedPosts rp
WHERE 
    rp.EditCount > 0  
ORDER BY 
    rp.Rank
LIMIT 100;