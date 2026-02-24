
WITH PostDetails AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Body,
           p.Tags,
           u.DisplayName AS OwnerDisplayName,
           p.CreationDate,
           ph.CreationDate AS LastEdited,
           COUNT(c.Id) AS CommentCount,
           COUNT(v.Id) AS VoteCount,
           ARRAY_AGG(DISTINCT t.TagName) AS TagNames
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistory ph ON ph.PostId = p.Id 
                               AND ph.PostHistoryTypeId IN (4, 5, 6)  
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    LEFT JOIN Tags t ON t.TagName IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')))
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.Title, p.Body, u.DisplayName, p.CreationDate, ph.CreationDate
), 
RankedPosts AS (
    SELECT PostId,
           Title,
           OwnerDisplayName,
           CreationDate,
           LastEdited,
           CommentCount,
           VoteCount,
           RANK() OVER (ORDER BY VoteCount DESC, CreationDate DESC) AS Rank
    FROM PostDetails
)
SELECT rp.PostId,
       rp.Title,
       rp.OwnerDisplayName,
       rp.CreationDate,
       rp.LastEdited,
       rp.CommentCount,
       rp.VoteCount,
       CASE 
           WHEN rp.VoteCount > 10 THEN 'Popular'
           WHEN rp.CommentCount > 5 THEN 'Engaging'
           ELSE 'Average'
       END AS PostCategory,
       pd.TagNames
FROM RankedPosts rp
JOIN PostDetails pd ON rp.PostId = pd.PostId
ORDER BY rp.Rank;
